DIR_BUILD    := ./target
DIR_DEBUG    := $(DIR_BUILD)/debug
DIR_RELEASE  := $(DIR_BUILD)/release
DIR_OBJS_D   := $(DIR_DEBUG)/objs
DIR_DEPS_D   := $(DIR_DEBUG)/deps
DIR_OBJS_R   := $(DIR_RELEASE)/objs
DIR_DEPS_R   := $(DIR_RELEASE)/deps
DIR_SRCS     := ./src
DIR_INCL     := ./include

FILES_SRCS   := $(shell find . -wholename "$(DIR_SRCS)/*.cpp")
FILES_OBJS_D := $(patsubst $(DIR_SRCS)/%.cpp,$(DIR_OBJS_D)/%.o,$(FILES_SRCS))
FILES_DEPS_D := $(patsubst $(DIR_SRCS)/%.cpp,$(DIR_DEPS_D)/%.d,$(FILES_SRCS))
FILES_OBJS_R := $(patsubst $(DIR_SRCS)/%.cpp,$(DIR_OBJS_R)/%.o,$(FILES_SRCS))
FILES_DEPS_R := $(patsubst $(DIR_SRCS)/%.cpp,$(DIR_DEPS_R)/%.d,$(FILES_SRCS))

OPT          := -O2
DEBUG        := -g                           \
				-fsanitize=address,undefined \
				-D_FORTIFY_SOURCE=2          \
				-D_GLIBCXX_ASSERTIONS
LIBS         :=

C_COMPILER   := clang++
I_FLAGS      := $(foreach dir,$(DIR_INCL),-I$(dir) )
SILENCED     := 
C_WARNS      := -Wall                   \
				-Wextra                 \
				-Werror                 \
				-Wpedantic              \
				-Wcast-align            \
				-Wconversion            \
				-Wsign-promo            \
				-Wunused                \
				-Wshadow                \
				-Wold-style-cast        \
				-Wpointer-arith         \
				-Wformat=2              \
				-Wno-format-nonliteral  \
				-Weffc++                \
				-Wc++17-compat          \
				-Wc++17-extensions      \
				-Wc++17-compat-pedantic \
				$(SILENCED) $(I_FLAGS)
C_DEPS       := -MM -MP $(I_FLAGS)

BIN          := icbm

# dim white italic
DIM      := \033[2;3;37m

# bold cyan
INFO     := \033[1;36m

# bold green
PASS     := \033[1;32m

# bold red
WARN     := \033[1;31m

RESET    := \033[0m

.PHONY: all
all:
	@echo todo

.PHONY: build-debug
build-debug: $(FILES_OBJS_D) $(FILES_DEPS_D)
	@echo -e "building $(PASS)$(DIR_DEBUG)/$(BIN)$(RESET) - $(DIM)debug$(RESET)"
	@$(C_COMPILER) $(C_WARNS) $(DEBUG) -o $(DIR_DEBUG)/$(BIN) $(FILES_OBJS_D)

PHONY: build-release
build-release: $(FILES_OBJS_R) $(FILES_DEPS_R)
	@echo -e "building $(PASS)$(DIR_RELEASE)/$(BIN)$(RESET)"
	@$(C_COMPILER) $(C_WARNS) $(DEBUG) -o $(DIR_RELEASE)/$(BIN) $(FILES_OBJS_R)

.PHONY: run-debug
run-debug: $(DIR_DEBUG)/$(BIN)
	@echo -e "running $(PASS)$(DIR_DEBUG)/$(BIN)$(RESET) - $(DIM)debug$(RESET)"
	@$(DIR_DEBUG)/$(BIN)

.PHONY: run-release
run-release: $(DIR_RELEASE)/$(BIN)
	@echo -e "running $(PASS)$(DIR_RELEASE)/$(BIN)$(RESET)"
	@$(DIR_RELEASE)/$(BIN)

.PHONY: clean-debug
clean-debug: _confirm
	@echo -e "removing $(WARN)all debug$(RESET) artefacts"
	@rm -rf $(FILES_OBJS_D) $(FILES_DEPS_D) $(DIR_DEBUG)/$(BIN)

.PHONY: clean-release
clean-release: _confirm
	@echo -e "removing $(WARN)all release$(RESET) artefacts"
	@rm -rf $(FILES_OBJS_R) $(FILES_DEPS_R) $(DIR_RELEASE)/$(BIN)

.PHONY: clean
clean: _confirm
	@echo -e "removing $(WARN)all$(RESET) artefacts"
	@rm -rf $(FILES_OBJS_D) $(FILES_DEPS_D) $(DIR_DEBUG)/$(BIN) \
			$(FILES_OBJS_R) $(FILES_DEPS_R) $(DIR_RELEASE)/$(BIN)

.PHONY: fmt
fmt:
	@echo -e "formatting all source files"
	clang-format -i $(FILES_SRCS)

.PHONY: _confirm
_confirm:
	@echo -e "$(WARN)This action will result in irrecoverable loss of data!$(RESET)"
	@echo -e "$(DIM)Are you sure you want to proceed?$(RESET) $(PASS)[y/N] $(RESET)" && \
	read ans && \
	case "$$ans" in \
		[yY]*) true;; \
		*) false;; \
	esac

.PHONY: info
info:
	@echo -e "$(INFO)[ FILES ]$(RESET)"
	@echo -e "Build directory:  $(DIM)$(DIR_BUILD)$(RESET)" 
	@echo -e "Source files   :  $(DIM)$(FILES_SRCS)$(RESET)" 
	@echo -e "Object files   :  $(DIM)$(FILES_OBJS_D) $(FILES_OBJS_R)$(RESET)" 
	@echo -e "Depend files   :  $(DIM)$(FILES_DEPS_D) $(FILES_DEPS_R)$(RESET)" 
	@echo -e "$(INFO)[ COMPILATION ]$(RESET)"
	@echo -e "Compiler       : $(DIM)$(C_COMPILER)$(RESET)"
	@echo -e "Warnings       : $(DIM)$(C_WARNS)$(RESET)"
	@echo -e "Debug          : $(DIM)$(DEBUG)$(RESET)"
	@echo -e "Optimizations  : $(DIM)$(OPT)$(RESET)"
	@echo -e "Binary         : $(DIM)$(BIN)$(RESET)"

$(DIR_DEBUG)/$(BIN):
	@make --silent debug

$(DIR_RELEASE)/$(BIN):
	@make --silent release

$(DIR_OBJS_D)%.o: $(DIR_SRCS)/%.cpp
	@echo -e "compiling $(INFO)$@$(RESET) - $(DIM)debug$(RESET)"
	@mkdir -p $(@D)
	@$(C_COMPILER) $(C_WARNS) $(DEBUG) -c $< -o $@

$(DIR_OBJS_R)%.o: $(DIR_SRCS)/%.cpp
	@echo -e "compiling $(INFO)$@$(RESET)"
	@mkdir -p $(@D)
	@$(C_COMPILER) $(C_WARNS) $(OPT) -c $< -o $@

$(DIR_DEPS_D)%.d: $(DIR_SRCS)/%.cpp
	@mkdir -p $(@D)
	@$(C_COMPILER) $(C_WARNS) $(C_DEPS) -MT $(DIR_OBJS_D)/$*.o -MF $@ $<

$(DIR_DEPS_R)%.d: $(DIR_SRCS)/%.cpp
	@mkdir -p $(@D)
	@$(C_COMPILER) $(C_WARNS) $(C_DEPS) -MT $(DIR_OBJS_R)/$*.o -MF $@ $<

-include $(FILES_DEPS_D) $(FILES_DEPS_R)

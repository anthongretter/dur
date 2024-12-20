# DUR Makefile

# Args
IP 		?= 127.0.0.1
PORT 	?= 8000
ID		?= 0

# Directories
DUR := $(abspath $(dir .))
SRC := $(DUR)/src
INC := $(DUR)/include
TMP := $(DUR)/tmp

# Compiling flags
CXX       := g++
CXXFLAGS  := -Wall -Wextra
CPPFLAGS  := -I$(INC)
LDFLAGS   := -lstdc++
LDLIBS    :=

# Aliases
RM    	:= rm -fr
MKDIR	:= mkdir -p
TERM  	:= konsole
TERMCMD	:= $(TERM) --hold --new-tab -e
KILL  	:= killall

# Files
CLIENT_TARGET     := cliente
SERVER_TARGET     := servidor
SEQUENCER_TARGET  := sequenciador
MOCK_TARGET		  := mock
CLIENT_SRCS       := $(SRC)/main_cliente.cpp $(filter-out $(SRC)/main_servidor.cpp $(SRC)/main_sequenciador.cpp $(SRC)/main_mock.cpp, $(shell find $(SRC) -type f -name "*.cpp"))
SERVER_SRCS       := $(SRC)/main_servidor.cpp $(filter-out $(SRC)/main_cliente.cpp $(SRC)/main_sequenciador.cpp $(SRC)/main_mock.cpp, $(shell find $(SRC) -type f -name "*.cpp"))
SEQUENCER_SRCS    := $(SRC)/main_sequenciador.cpp $(filter-out $(SRC)/main_servidor.cpp $(SRC)/main_cliente.cpp $(SRC)/main_mock.cpp, $(shell find $(SRC) -type f -name "*.cpp"))
MOCK_SRCS		  := $(SRC)/main_mock.cpp $(filter-out $(SRC)/main_servidor.cpp $(SRC)/main_cliente.cpp $(SRC)/main_sequenciador.cpp, $(shell find $(SRC) -type f -name "*.cpp"))
CLIENT_OBJS		  := $(CLIENT_SRCS:.cpp=.o)
SERVER_OBJS       := $(SERVER_SRCS:.cpp=.o)
MOCK_OBJS         := $(MOCK_SRCS:.cpp=.o)
SEQUENCER_OBJS    := $(SEQUENCER_SRCS:.cpp=.o)

HS                := $(wildcard $(INC)/*.hpp)
CONF			  := $(DUR)/servidores_config.txt


$(CLIENT_TARGET): $(CLIENT_OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(SERVER_TARGET): $(SERVER_OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(SEQUENCER_TARGET): $(SEQUENCER_OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(MOCK_TARGET): $(MOCK_OBJS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

all: $(CLIENT_TARGET) $(SERVER_TARGET) $(SEQUENCER_TARGET) $(MOCK_TARGET)


run_cliente: $(CLIENT_TARGET)
	@clear && ./$(CLIENT_TARGET) $(IP) $(PORT)

run_servidor: $(SERVER_TARGET)
	@clear && ./$(SERVER_TARGET) $(ID)

run_sequencer: $(SEQUENCER_TARGET)
	@clear && ./$(SEQUENCER_TARGET)

infra: $(SERVER_TARGET) $(SEQUENCER_TARGET)
	$(MKDIR) $(TMP)
	($(TERMCMD) "./$(SEQUENCER_TARGET)" &)
	for server_id in $(shell awk -F":|," 'NR>1 {printf "%d ", $$1}' $(CONF)) ; do \
		(! [[ -f $(TMP)/dataSet$${server_id}.json ]] && echo "{}" > $(TMP)/dataSet$${server_id}.json); \
		($(TERMCMD) "./$(SERVER_TARGET) $$server_id" &) ; \
	done

test: $(MOCK_TARGET) infra
	@clear && echo "Waiting a bit for infra..." && sleep 2 && ./$(MOCK_TARGET) $(TEST)

stop:
	$(KILL) $(TERM)

clean:
	$(RM) $(CLIENT_OBJS) $(SERVER_OBJS) $(SEQUENCER_OBJS) $(MOCK_OBJS) $(CLIENT_TARGET) $(SERVER_TARGET) $(SEQUENCER_TARGET) $(MOCK_TARGET)

cleandata:
	$(RM) $(TMP)

.PHONY: all

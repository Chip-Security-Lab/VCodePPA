//SystemVerilog

module FsmMux #(parameter DW=4) (
    input wire clk,
    input wire rst,
    input wire [1:0] cmd,
    output wire [DW-1:0] data
);

    // State encoding with parameters
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] CH0  = 2'b01;
    localparam [1:0] CH1  = 2'b10;

    // State register
    reg [1:0] state_reg;
    // Pipeline register for next_state
    reg [1:0] next_state_pipe_reg;
    // Pipeline register for data output
    reg [DW-1:0] data_pipe_reg;

    wire [1:0] next_state_comb;
    wire [DW-1:0] data_comb;

    // Combinational next state logic
    FsmMux_next_state u_next_state(
        .state_in(state_reg),
        .cmd_in(cmd),
        .next_state_out(next_state_comb)
    );

    // Pipeline register for next_state (cutting critical path after combinational logic)
    always @(posedge clk or posedge rst) begin
        if (rst)
            next_state_pipe_reg <= IDLE;
        else
            next_state_pipe_reg <= next_state_comb;
    end

    // State register update (sequential, now from pipeline reg)
    always @(posedge clk or posedge rst) begin
        if (rst)
            state_reg <= IDLE;
        else
            state_reg <= next_state_pipe_reg;
    end

    // Combinational output logic with pipelined input
    FsmMux_output_logic #(.DW(DW)) u_output_logic(
        .state_in(state_reg),
        .data_out(data_comb)
    );

    // Pipeline register for output data (cutting critical path after output logic)
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_pipe_reg <= {DW{1'b0}};
        else
            data_pipe_reg <= data_comb;
    end

    // Registered output
    assign data = data_pipe_reg;

endmodule

// Next state combinational logic module
module FsmMux_next_state (
    input wire [1:0] state_in,
    input wire [1:0] cmd_in,
    output reg [1:0] next_state_out
);
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] CH0  = 2'b01;
    localparam [1:0] CH1  = 2'b10;

    always @(*) begin
        case (state_in)
            IDLE: next_state_out = (cmd_in[0]) ? CH0 : CH1;
            CH0:  next_state_out = (cmd_in[1]) ? CH1 : IDLE;
            CH1:  next_state_out = IDLE;
            default: next_state_out = IDLE;
        endcase
    end
endmodule

// Output combinational logic module
module FsmMux_output_logic #(parameter DW=4) (
    input wire [1:0] state_in,
    output reg [DW-1:0] data_out
);
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] CH0  = 2'b01;
    localparam [1:0] CH1  = 2'b10;

    always @(*) begin
        case (state_in)
            CH0: data_out = 4'b0001;
            CH1: data_out = 4'b1000;
            default: data_out = 4'b0000;
        endcase
    end
endmodule
//SystemVerilog
module sram_latency #(
    parameter DW = 8,
    parameter AW = 4,
    parameter LATENCY = 3
)(
    input clk,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] pipe_reg [0:LATENCY-1];
reg [DW-1:0] pipe_reg_buf [0:LATENCY-1];
reg [$clog2(LATENCY):0] state;
reg [$clog2(LATENCY):0] state_buf;
reg [$clog2(LATENCY):0] next_state;
reg [$clog2(LATENCY):0] next_state_buf;

localparam IDLE = 0;
localparam SHIFT = 1;

// Buffer registers for high fanout signals
always @(posedge clk) begin
    if (ce) begin
        state_buf <= state;
        next_state_buf <= next_state;
        for (int i = 0; i < LATENCY; i++) begin
            pipe_reg_buf[i] <= pipe_reg[i];
        end
    end
end

// Main state machine
always @(posedge clk) begin
    if (ce) begin
        if (we) mem[addr] <= din;
        pipe_reg[0] <= mem[addr];
        state <= next_state_buf;
    end
end

// Next state logic with buffered signals
always @(*) begin
    next_state = state_buf;
    case(state_buf)
        IDLE: begin
            if (ce) next_state = SHIFT;
        end
        SHIFT: begin
            if (state_buf < LATENCY) begin
                pipe_reg[state_buf] <= pipe_reg_buf[state_buf-1];
                next_state = state_buf + 1;
            end else begin
                next_state = IDLE;
            end
        end
    endcase
end

assign dout = pipe_reg_buf[LATENCY-1];

endmodule
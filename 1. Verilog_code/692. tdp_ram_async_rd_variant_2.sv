//SystemVerilog
module tdp_ram_async_rd #(
    parameter DW = 16,
    parameter AW = 5,
    parameter DEPTH = 32
)(
    input clk, rst_n,
    // Port A
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output [DW-1:0] a_dout,
    input a_wr,
    // Port B
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output [DW-1:0] b_dout,
    input b_wr
);

reg [DW-1:0] storage [0:DEPTH-1];
reg [AW-1:0] init_addr;
reg init_done;

// State machine states
typedef enum logic [1:0] {
    IDLE,
    INIT,
    NORMAL
} state_t;

state_t current_state, next_state;

// Asynchronous read
assign a_dout = storage[a_addr];
assign b_dout = storage[b_addr];

// State machine logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        init_addr <= 0;
        init_done <= 0;
    end else begin
        current_state <= next_state;
    end
end

// Next state logic
always @(*) begin
    case (current_state)
        IDLE: begin
            if (!rst_n) begin
                next_state = INIT;
            end else begin
                next_state = NORMAL;
            end
        end
        INIT: begin
            if (init_addr == DEPTH-1) begin
                next_state = NORMAL;
            end else begin
                next_state = INIT;
            end
        end
        NORMAL: begin
            next_state = NORMAL;
        end
        default: next_state = IDLE;
    endcase
end

// Output logic
always @(posedge clk) begin
    case (current_state)
        INIT: begin
            storage[init_addr] <= 0;
            init_addr <= init_addr + 1;
        end
        NORMAL: begin
            if (a_wr) storage[a_addr] <= a_din;
            if (b_wr) storage[b_addr] <= b_din;
        end
        default: begin
            // Do nothing
        end
    endcase
end

endmodule
//SystemVerilog
module SyncLatch #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

// Pipeline stage 1 registers
reg [1:0] state_stage1;
reg [WIDTH-1:0] d_stage1;
reg en_stage1;

// Pipeline stage 2 registers
reg [1:0] state_stage2;
reg [WIDTH-1:0] d_stage2;
reg en_stage2;

localparam RESET = 2'b00;
localparam HOLD = 2'b01;
localparam UPDATE = 2'b10;

// Stage 1: Input capture and state transition
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state_stage1 <= RESET;
        d_stage1 <= 0;
        en_stage1 <= 0;
    end else begin
        d_stage1 <= d;
        en_stage1 <= en;
        
        case(state_stage1)
            RESET: state_stage1 <= (en) ? UPDATE : HOLD;
            HOLD: state_stage1 <= (en) ? UPDATE : HOLD;
            UPDATE: state_stage1 <= (en) ? UPDATE : HOLD;
            default: state_stage1 <= HOLD;
        endcase
    end
end

// Stage 2: Data processing and output
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state_stage2 <= RESET;
        d_stage2 <= 0;
        en_stage2 <= 0;
        q <= 0;
    end else begin
        state_stage2 <= state_stage1;
        d_stage2 <= d_stage1;
        en_stage2 <= en_stage1;
        
        case(state_stage2)
            RESET: q <= (en_stage2) ? d_stage2 : 0;
            HOLD: q <= (en_stage2) ? d_stage2 : q;
            UPDATE: q <= (en_stage2) ? d_stage2 : q;
            default: q <= q;
        endcase
    end
end

endmodule
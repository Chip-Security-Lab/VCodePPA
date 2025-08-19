//SystemVerilog
module i2c_low_power #(
    parameter AUTO_CLKGATE = 1  // Automatic clock gating
)(
    input clk_main,
    input rst_n,
    input enable,
    inout sda,
    inout scl,
    output reg clk_gated
);

// Pipeline stage parameters
parameter IDLE = 2'b00;
parameter ACTIVE = 2'b01;
parameter TRANSFER = 2'b10;

// State and data signals before registering
wire [1:0] next_state;
wire [3:0] next_fifo_count;
wire next_clk_enable;

// Pipeline stage registers
reg [1:0] state_stage2;
reg [3:0] fifo_count_stage2;
reg enable_stage2;
reg clk_enable_reg_stage2;
reg valid_stage2;

// Clock gating logic - moved after combinational logic
wire gated_clk = clk_main & clk_enable_reg_stage2;

// Combinational logic for state calculation and FIFO count
assign next_state = (!enable && (state_stage2 == IDLE || state_stage2 == ACTIVE)) ? IDLE :
                    (enable && (state_stage2 == IDLE || state_stage2 == ACTIVE)) ? ACTIVE :
                    IDLE;

assign next_fifo_count = (enable && fifo_count_stage2 < 4'hF) ? fifo_count_stage2 + 1 :
                        (!enable && fifo_count_stage2 > 0) ? fifo_count_stage2 - 1 :
                        fifo_count_stage2;

assign next_clk_enable = (next_state != IDLE) || (|next_fifo_count);

// Pipeline stage 2: Registers after combinational logic
always @(posedge clk_main or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2 <= IDLE;
        fifo_count_stage2 <= 4'h0;
        enable_stage2 <= 1'b0;
        clk_enable_reg_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else begin
        // Register the outputs of combinational logic directly
        state_stage2 <= next_state;
        fifo_count_stage2 <= next_fifo_count;
        enable_stage2 <= enable;
        valid_stage2 <= 1'b1;
        
        // Clock gating control logic - moved after combinational calculation
        clk_enable_reg_stage2 <= next_clk_enable;
    end
end

// Output generation - moved to a separate always block for clarity
always @(posedge clk_main or negedge rst_n) begin
    if (!rst_n) begin
        clk_gated <= 1'b0;
    end else if (valid_stage2) begin
        clk_gated <= gated_clk;
    end
end

// Using clock gating unit (synthesis directive)
// synopsys translate_off
initial $display("Using optimized pipelined clock gating technique with forward retiming");
// synopsys translate_on

endmodule
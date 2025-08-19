//SystemVerilog
//IEEE 1364-2005 Verilog
module video_timing #(parameter H_TOTAL=800)(
    input wire clk,
    input wire rst_n,    // Added reset signal for proper pipeline control
    output reg h_sync,
    output reg [9:0] h_count,
    output reg valid_out // Added valid signal to indicate valid pipeline output
);
    // Pipeline stage 1 registers
    reg [9:0] cnt_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [9:0] cnt_stage2;
    reg valid_stage2;
    
    // Combinational logic for stage 1
    wire [9:0] next_cnt;
    assign next_cnt = (cnt_stage2 < H_TOTAL-1) ? cnt_stage2 + 1 : 10'd0;
    
    // Combinational logic for stage 2
    wire next_h_sync;
    assign next_h_sync = (cnt_stage1 < 96) ? 1'b0 : 1'b1;
    
    // Pipeline stage 1: Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 10'd0;
            valid_stage1 <= 1'b0;
        end else begin
            cnt_stage1 <= next_cnt;
            valid_stage1 <= 1'b1; // Always valid after reset
        end
    end
    
    // Pipeline stage 2: Sync signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage2 <= 10'd0;
            h_sync <= 1'b1; // Default sync state
            valid_stage2 <= 1'b0;
        end else begin
            cnt_stage2 <= cnt_stage1;
            h_sync <= next_h_sync;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
            valid_out <= 1'b0;
        end else begin
            h_count <= cnt_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule
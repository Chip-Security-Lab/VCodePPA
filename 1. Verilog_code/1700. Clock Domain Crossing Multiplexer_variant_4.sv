//SystemVerilog
module cdc_mux(
    input clk_src, clk_dst, rst_n,
    input [15:0] data_a, data_b,
    input select,
    output reg [15:0] synced_out
);
    // Internal signals
    reg [15:0] mux_out;
    reg [15:0] meta_stage_1;
    reg [15:0] meta_stage_2;
    
    // Mux logic - combinational
    always @(*) begin
        mux_out = select ? data_b : data_a;
    end
    
    // First stage synchronization
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            meta_stage_1 <= 16'd0;
        end else begin
            meta_stage_1 <= mux_out;
        end
    end
    
    // Second stage synchronization
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            meta_stage_2 <= 16'd0;
        end else begin
            meta_stage_2 <= meta_stage_1;
        end
    end
    
    // Output stage
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            synced_out <= 16'd0;
        end else begin
            synced_out <= meta_stage_2;
        end
    end
endmodule
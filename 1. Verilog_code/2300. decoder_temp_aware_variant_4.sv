//SystemVerilog
module decoder_temp_aware #(parameter THRESHOLD=85) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] temp,
    input wire [3:0] addr,
    input wire valid_in,
    output wire valid_out,
    output reg [15:0] decoded
);
    // Stage 1 registers
    reg [7:0] temp_stage1;
    reg [3:0] addr_stage1;
    reg valid_stage1;
    reg temp_over_threshold;
    
    // Stage 2 registers
    reg [3:0] addr_stage2;
    reg valid_stage2;
    reg temp_over_threshold_stage2;
    reg [15:0] decoded_stage2;
    
    // Stage 1: Temp comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_stage1 <= 8'd0;
            addr_stage1 <= 4'd0;
            valid_stage1 <= 1'b0;
            temp_over_threshold <= 1'b0;
        end else begin
            temp_stage1 <= temp;
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
            temp_over_threshold <= (temp > THRESHOLD);
        end
    end
    
    // Stage 2: Shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'd0;
            valid_stage2 <= 1'b0;
            temp_over_threshold_stage2 <= 1'b0;
            decoded_stage2 <= 16'd0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            temp_over_threshold_stage2 <= temp_over_threshold;
            
            if (valid_stage1) begin
                if (temp_over_threshold)
                    decoded_stage2 <= (1'b1 << addr_stage1) & 16'h00FF; // 高温限制输出
                else
                    decoded_stage2 <= 1'b1 << addr_stage1;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 16'd0;
        end else if (valid_stage2) begin
            decoded <= decoded_stage2;
        end
    end
    
    assign valid_out = valid_stage2;
    
endmodule
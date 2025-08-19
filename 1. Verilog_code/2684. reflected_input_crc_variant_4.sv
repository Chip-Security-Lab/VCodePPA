//SystemVerilog
module reflected_input_crc(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire valid,
    output wire ready,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h8005;
    
    // 组合逻辑部分
    wire [7:0] reflected_data;
    wire [15:0] next_crc;
    wire processing_en;
    reg processing;
    
    // 数据反射逻辑
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: reflect
            assign reflected_data[i] = data_in[7-i];
        end
    endgenerate
    
    // Valid-Ready握手逻辑
    assign ready = !processing;
    assign processing_en = valid && ready;
    
    // CRC计算组合逻辑
    assign next_crc = {crc_out[14:0], 1'b0} ^ 
                     ((crc_out[15] ^ reflected_data[0]) ? POLY : 16'h0000);
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if (reset) begin
            crc_out <= 16'hFFFF;
            processing <= 1'b0;
        end
        else begin
            if (processing_en) begin
                crc_out <= next_crc;
                processing <= 1'b1;
            end
            else if (processing) begin
                processing <= 1'b0;
            end
        end
    end
endmodule
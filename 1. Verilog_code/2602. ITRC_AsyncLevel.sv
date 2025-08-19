module ITRC_AsyncLevel #(
    parameter PRIORITY = 4'hF
)(
    input clk,
    input rst_async,        // 异步复位
    input [15:0] int_level, // 电平触发源
    input en,               // 全局使能
    output reg [3:0] int_id     // 当前中断ID
);
    wire [15:0] masked_int = int_level & {16{en}};
    
    // Implement full priority encoder
    always @(*) begin
        if (masked_int[15]) int_id = 4'hF;
        else if (masked_int[14]) int_id = 4'hE;
        else if (masked_int[13]) int_id = 4'hD;
        else if (masked_int[12]) int_id = 4'hC;
        else if (masked_int[11]) int_id = 4'hB;
        else if (masked_int[10]) int_id = 4'hA;
        else if (masked_int[9]) int_id = 4'h9;
        else if (masked_int[8]) int_id = 4'h8;
        else if (masked_int[7]) int_id = 4'h7;
        else if (masked_int[6]) int_id = 4'h6;
        else if (masked_int[5]) int_id = 4'h5;
        else if (masked_int[4]) int_id = 4'h4;
        else if (masked_int[3]) int_id = 4'h3;
        else if (masked_int[2]) int_id = 4'h2;
        else if (masked_int[1]) int_id = 4'h1;
        else if (masked_int[0]) int_id = 4'h0;
        else int_id = 4'h0;
    end
    
    // Reset logic
    reg reset_sync;
    always @(posedge clk, posedge rst_async) begin
        if (rst_async) 
            reset_sync <= 1'b1;
        else 
            reset_sync <= 1'b0;
    end
endmodule
//SystemVerilog
module crossbar_addr_decode #(
    parameter AW = 4,
    parameter DW = 16,
    parameter N  = 8
) (
    input wire            clk,
    input wire [DW-1:0]   data_in,
    input wire [AW-1:0]   addr,
    output wire [N*DW-1:0] data_out
);
    // 显式地声明地址解码信号
    reg [N-1:0] decoder_out;
    
    // 地址解码逻辑
    always @(*) begin
        integer i;
        decoder_out = {N{1'b0}};
        
        // 显式的解码器实现，使用if-else结构替代条件运算符
        for (i = 0; i < N; i = i + 1) begin
            if (addr == i) begin
                decoder_out[i] = 1'b1;
            end
            else begin
                decoder_out[i] = 1'b0;
            end
        end
    end
    
    // 显式的多路复用器结构
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin: gen_out
            // 使用显式的多路复用器模式, 使用if-else结构的连续赋值
            wire [DW-1:0] mux_out;
            wire mux_sel;
            wire [DW-1:0] mux_in1;
            wire [DW-1:0] mux_in0;
            
            assign mux_sel = decoder_out[g];
            assign mux_in1 = data_in;
            assign mux_in0 = {DW{1'b0}};
            
            // 使用if-else结构替代条件运算符的assign语句
            reg [DW-1:0] mux_temp;
            always @(*) begin
                if (mux_sel) begin
                    mux_temp = mux_in1;
                end
                else begin
                    mux_temp = mux_in0;
                end
            end
            
            assign mux_out = mux_temp;
            
            // 连接到输出
            assign data_out[(g*DW) +: DW] = mux_out;
        end
    endgenerate
endmodule
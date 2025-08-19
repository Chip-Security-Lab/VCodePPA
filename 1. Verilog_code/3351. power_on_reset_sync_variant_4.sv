//SystemVerilog
module power_on_reset_sync (
    input  wire clk,
    input  wire ext_rst_n,
    output wire por_rst_n
);
    reg [2:0] por_counter;
    reg       por_done;
    reg       ext_rst_stable;
    reg       ext_rst_meta;
    
    initial begin
        por_counter = 3'b000;
        por_done = 1'b0;
        ext_rst_stable = 1'b0;
        ext_rst_meta = 1'b0;
    end
    
    // 前同步器阶段，直接在输入处捕获外部复位信号
    always @(posedge clk) begin
        ext_rst_meta <= ext_rst_n;
    end
    
    // 带复位功能的第二级同步器和计数逻辑
    always @(posedge clk) begin
        if (!ext_rst_meta) begin  // 使用同步后的复位信号
            ext_rst_stable <= 1'b0;
            por_counter <= 3'b000;
            por_done <= 1'b0;
        end else begin
            ext_rst_stable <= 1'b1;
            
            if (!por_done)
                if (por_counter < 3'b111)
                    por_counter <= por_counter + 1;
                else
                    por_done <= 1'b1;
        end
    end
    
    assign por_rst_n = ext_rst_stable & por_done;
endmodule
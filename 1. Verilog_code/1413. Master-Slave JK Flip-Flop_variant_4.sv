//SystemVerilog
module ms_jk_flip_flop (
    input wire clk,
    input wire j,
    input wire k,
    output wire q
);
    reg master;
    reg master_buf1, master_buf2;  // 缓冲寄存器
    reg slave;
    
    always @(posedge clk) begin
        case ({j, k})
            2'b00: master <= master;
            2'b01: master <= 1'b0;
            2'b10: master <= 1'b1;
            2'b11: master <= ~master;
        endcase
        
        // 缓冲寄存器，减轻master信号的扇出负载
        master_buf1 <= master;
        master_buf2 <= master;
    end
    
    always @(negedge clk) begin
        slave <= master_buf1;
    end
    
    assign q = slave;
endmodule
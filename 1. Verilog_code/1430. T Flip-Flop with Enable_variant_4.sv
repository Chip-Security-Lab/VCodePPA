//SystemVerilog
// SystemVerilog
module t_ff_enable (
    input wire clk,
    input wire en,
    input wire t,
    output wire q
);
    // IEEE 1364-2005 Verilog标准
    reg internal_q;
    reg retimed_en_t;
    
    always @(posedge clk) begin
        retimed_en_t <= en & t;
    end
    
    always @(posedge clk) begin
        if (retimed_en_t) begin
            internal_q <= ~internal_q;
        end
    end
    
    assign q = internal_q;
endmodule
//SystemVerilog
module power_opt_divider (
    input clock_i, nreset_i, enable_i,
    output clock_o
);
    reg [2:0] div_cnt;
    reg div_out;
    reg enable_reg;
    
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            enable_reg <= 1'b0;
        end else begin
            enable_reg <= enable_i;
        end
    end
    
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            div_cnt <= 3'b000;
            div_out <= 1'b0;
        end else if (enable_reg) begin
            if (div_cnt == 3'b110) begin
                div_cnt <= 3'b111;
            end else if (div_cnt == 3'b111) begin
                div_cnt <= 3'b000;
                div_out <= ~div_out;
            end else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end
    
    assign clock_o = enable_reg ? div_out : 1'b0;
endmodule
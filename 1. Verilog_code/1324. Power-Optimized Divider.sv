module power_opt_divider (
    input clock_i, nreset_i, enable_i,
    output clock_o
);
    reg [2:0] div_cnt;
    reg div_out;
    wire cnt_done;
    
    assign cnt_done = (div_cnt == 3'b111);
    
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            div_cnt <= 3'b000;
            div_out <= 1'b0;
        end else if (enable_i) begin
            div_cnt <= cnt_done ? 3'b000 : div_cnt + 1'b1;
            div_out <= cnt_done ? ~div_out : div_out;
        end
    end
    
    assign clock_o = div_out & enable_i;
endmodule
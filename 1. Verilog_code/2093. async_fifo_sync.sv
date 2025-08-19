module pulse_sync_expand (
    input src_clk, dst_clk, rst,
    input src_pulse,
    output dst_pulse
);
    reg src_flag, dst_flag0, dst_flag1;
    always @(posedge src_clk or posedge rst) begin
        if(rst) src_flag <= 0;
        else src_flag <= src_pulse ? ~src_flag : src_flag;
    end
    always @(posedge dst_clk) begin
        {dst_flag1, dst_flag0} <= {dst_flag0, src_flag};
    end
    assign dst_pulse = (dst_flag1 ^ dst_flag0);
endmodule
module sd_cmd_encoder (
    input clk, cmd_en,
    input [5:0] cmd,
    input [31:0] arg,
    output reg cmd_out
);
    reg [47:0] shift_reg;
    reg [5:0] cnt;
    always @(posedge clk) begin
        if(cmd_en) begin
            shift_reg <= {1'b0, cmd, arg, 7'h01};
            cnt <= 47;
        end
        else if(cnt > 0) begin
            cmd_out <= shift_reg[cnt];
            cnt <= cnt - 1;
        end
    end
endmodule
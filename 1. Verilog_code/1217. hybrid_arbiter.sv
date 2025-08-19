module hybrid_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [1:0] rr_ptr;
integer i;
reg [1:0] idx;
reg break_flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        grant_o <= 0;
        rr_ptr <= 0;
    end else casez(req_i[3:2])
        2'b?1: grant_o <= 4'b0100;
        2'b10: grant_o <= 4'b1000;
        default: begin
            grant_o <= 0;
            break_flag = 0;
            for(i=0; i<2; i=i+1) begin
                idx = (rr_ptr + i) % 2;
                if(req_i[idx] && !break_flag) begin
                    grant_o <= 1 << idx;
                    rr_ptr <= idx + 1;
                    break_flag = 1;
                end
            end
        end
    endcase
end
endmodule
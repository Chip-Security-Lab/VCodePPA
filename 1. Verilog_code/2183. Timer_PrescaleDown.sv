module Timer_PrescaleDown #(parameter DIV=16) (
    input clk, rst_n, load_en,
    input [7:0] init_val,
    output reg timeup
);
    reg [7:0] counter;
    reg [$clog2(DIV)-1:0] ps_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps_cnt <= 0;
            counter <= 0;
        end else begin
            ps_cnt <= (ps_cnt == DIV-1) ? 0 : ps_cnt + 1;
            if (load_en) counter <= init_val;
            else if (ps_cnt == 0 && counter > 0)
                counter <= counter - 1;
            timeup <= (counter == 0);
        end
    end
endmodule
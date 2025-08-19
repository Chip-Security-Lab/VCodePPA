module debounce_ismu #(parameter CNT_WIDTH = 4)(
    input wire clk, rst,
    input wire [7:0] raw_intr,
    output reg [7:0] stable_intr
);
    reg [7:0] intr_r1, intr_r2;
    reg [CNT_WIDTH-1:0] counter [7:0];
    integer i;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_r1 <= 8'h0;
            intr_r2 <= 8'h0;
            stable_intr <= 8'h0;
            for (i = 0; i < 8; i = i + 1)
                counter[i] <= 0;
        end else begin
            intr_r1 <= raw_intr;
            intr_r2 <= intr_r1;
            
            for (i = 0; i < 8; i = i + 1) begin
                if (intr_r1[i] != intr_r2[i])
                    counter[i] <= 0;
                else if (counter[i] < {CNT_WIDTH{1'b1}})
                    counter[i] <= counter[i] + 1;
                else if (counter[i] == {CNT_WIDTH{1'b1}})
                    stable_intr[i] <= intr_r1[i];
            end
        end
    end
endmodule
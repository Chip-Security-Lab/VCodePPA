module countdown_timer #(
    parameter COUNT_WIDTH = 24
)(
    input clk_i,
    input rst_i,
    input start_i,
    input [COUNT_WIDTH-1:0] load_value_i,
    output reg zero_o,
    output reg intr_o
);
    reg [COUNT_WIDTH-1:0] count_r;
    reg running_r;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            count_r <= {COUNT_WIDTH{1'b0}};
            zero_o <= 1'b0;
            intr_o <= 1'b0;
            running_r <= 1'b0;
        end else if (start_i && !running_r) begin
            count_r <= load_value_i;
            running_r <= 1'b1;
            zero_o <= 1'b0;
            intr_o <= 1'b0;
        end else if (running_r) begin
            if (count_r == {{COUNT_WIDTH-1{1'b0}}, 1'b1}) begin
                count_r <= {COUNT_WIDTH{1'b0}};
                zero_o <= 1'b1;
                intr_o <= 1'b1;
                running_r <= 1'b0;
            end else begin
                count_r <= count_r - 1'b1;
            end
        end else begin
            intr_o <= 1'b0;
        end
    end
endmodule
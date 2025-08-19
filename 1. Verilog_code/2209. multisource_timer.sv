module multisource_timer #(
    parameter COUNTER_WIDTH = 16
)(
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    input wire [1:0] clk_sel,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] threshold,
    output reg event_out
);
    reg [COUNTER_WIDTH-1:0] counter;
    wire selected_clk;
    
    // Clock mux
    assign selected_clk = (clk_sel == 2'b00) ? clk_src_0 :
                         (clk_sel == 2'b01) ? clk_src_1 :
                         (clk_sel == 2'b10) ? clk_src_2 : clk_src_3;
    
    always @(posedge selected_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            event_out <= 1'b0;
        end else begin
            if (counter >= threshold - 1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                event_out <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                event_out <= 1'b0;
            end
        end
    end
endmodule
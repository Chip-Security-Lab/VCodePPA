//SystemVerilog
module even_divider #(
    parameter DIV_WIDTH = 8,
    parameter DIV_VALUE = 10
)(
    input wire clk_in,
    input wire rst_n,
    output wire clk_out
);

    // Counter pipeline stage
    reg [DIV_WIDTH-1:0] counter_r;
    reg counter_max_r;
    reg counter_half_r;
    
    // Pre-compute counter values
    wire [DIV_WIDTH-1:0] counter_next = (counter_max_r) ? {DIV_WIDTH{1'b0}} : counter_r + 1'b1;
    wire counter_max_next = (counter_next == DIV_VALUE-2);
    wire counter_half_next = (counter_next == (DIV_VALUE>>1)-1);
    
    // Counter logic pipeline
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_r <= {DIV_WIDTH{1'b0}};
            counter_max_r <= 1'b0;
            counter_half_r <= 1'b0;
        end else begin
            counter_r <= counter_next;
            counter_max_r <= counter_max_next;
            counter_half_r <= counter_half_next;
        end
    end
    
    // Clock output generation with retimed registers
    reg clk_out_r;
    reg clk_out_next;
    
    always @(*) begin
        if (counter_half_r)
            clk_out_next = 1'b1;
        else if (counter_max_r)
            clk_out_next = 1'b0;
        else
            clk_out_next = clk_out_r;
    end
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            clk_out_r <= 1'b0;
        else
            clk_out_r <= clk_out_next;
    end
    
    assign clk_out = clk_out_r;

endmodule
//SystemVerilog
module config_direction_comp #(parameter WIDTH = 8)(
    input clk, rst_n, 
    input direction,     // 0: MSB priority, 1: LSB priority
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);

    reg [WIDTH-1:0] priority_mask;
    reg [$clog2(WIDTH)-1:0] temp_priority;
    wire [WIDTH-1:0] data_in_rev;
    
    // Reverse data_in for MSB priority
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin
            assign data_in_rev[j] = data_in[WIDTH-1-j];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            priority_mask <= 0;
            temp_priority <= 0;
        end else begin
            if (direction) begin // LSB priority
                priority_mask <= data_in;
            end else begin       // MSB priority
                priority_mask <= data_in_rev;
            end
            
            temp_priority <= 0;
            for (int i = 0; i < WIDTH; i = i + 1) begin
                if (priority_mask[i]) begin
                    temp_priority <= i[$clog2(WIDTH)-1:0];
                end
            end
            
            if (direction) begin
                priority_out <= temp_priority;
            end else begin
                priority_out <= WIDTH-1 - temp_priority;
            end
        end
    end
endmodule
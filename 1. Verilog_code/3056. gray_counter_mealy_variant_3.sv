//SystemVerilog
module gray_counter_mealy(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire up_down,
    input wire req,
    output reg ack,
    output reg [3:0] gray_out
);
    reg [3:0] binary_count, next_binary;
    reg data_valid;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            binary_count <= 4'b0000;
            data_valid <= 1'b0;
            ack <= 1'b0;
        end
        else begin
            if (req && !data_valid) begin
                if (enable) begin
                    binary_count <= next_binary;
                    data_valid <= 1'b1;
                    ack <= 1'b1;
                end
            end
            else if (data_valid && !req) begin
                data_valid <= 1'b0;
                ack <= 1'b0;
            end
        end
    end
    
    always @(*) begin
        if (up_down)
            next_binary = binary_count - 1'b1;
        else
            next_binary = binary_count + 1'b1;
            
        if (data_valid)
            gray_out = {binary_count[3], binary_count[3:1] ^ binary_count[2:0]};
        else
            gray_out = 4'b0;
    end
endmodule
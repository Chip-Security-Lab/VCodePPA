//SystemVerilog
module prio_encoder #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input dir,
    output reg [$clog2(WIDTH)-1:0] encoded,
    output reg valid
);
    reg [WIDTH-1:0] mask;
    reg [WIDTH-1:0] isolated_bit;
    integer i;
    
    always @(*) begin
        valid = |data_in;
        
        if (dir) begin
            // MSB优先
            mask = {1'b0, {WIDTH-1{1'b1}}};
            isolated_bit = data_in & ~(data_in & mask);
            
            encoded = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1) begin
                if (isolated_bit[i]) encoded = i;
            end
        end else begin
            // LSB优先
            mask = {{WIDTH-1{1'b1}}, 1'b0};
            isolated_bit = data_in & ~(data_in & mask);
            
            encoded = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (isolated_bit[i]) encoded = i;
            end
        end
    end
endmodule
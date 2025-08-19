//SystemVerilog
module prio_encoder #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input dir, // 0:LSB优先 1:MSB优先
    output reg [$clog2(WIDTH)-1:0] encoded,
    output reg valid
);
    integer i;
    
    always @(*) begin
        encoded = 0;
        valid = |data_in;
        
        for(i=0; i<WIDTH; i=i+1) begin
            if (dir && data_in[WIDTH-1-i]) 
                encoded = WIDTH-1-i;
            else if (!dir && data_in[i]) 
                encoded = i;
        end
    end
endmodule
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
        
        if (dir) begin
            // MSB优先
            for(i=WIDTH-1; i>=0; i=i-1)
                if (data_in[i]) encoded = i;
        end else begin
            // LSB优先
            for(i=0; i<WIDTH; i=i+1)
                if (data_in[i]) encoded = i;
        end
    end
endmodule
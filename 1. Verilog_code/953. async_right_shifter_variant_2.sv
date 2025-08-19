//SystemVerilog
module async_right_shifter (
    input data_in,
    input [3:0] control,
    output reg data_out
);
    reg [4:0] internal;
    
    always @(*) begin
        internal[4] = data_in;
        
        if (control[3])
            internal[3] = internal[4];
        else
            internal[3] = 1'bz;
            
        if (control[2])
            internal[2] = internal[3];
        else
            internal[2] = 1'bz;
            
        if (control[1])
            internal[1] = internal[2];
        else
            internal[1] = 1'bz;
            
        if (control[0])
            internal[0] = internal[1];
        else
            internal[0] = 1'bz;
            
        data_out = internal[0];
    end
endmodule
module priority_demux (
    input wire data_in,                  // Input data
    input wire [2:0] pri_select,         // Priority selection
    output reg [7:0] dout                // Output channels
);
    always @(*) begin
        dout = 8'b0;
        
        // Priority encoded selection
        if (pri_select[2])
            dout[7:4] = {4{data_in}} & {data_in, data_in, data_in, data_in};
        else if (pri_select[1])
            dout[3:2] = {2{data_in}} & {data_in, data_in};
        else if (pri_select[0])
            dout[1] = data_in;
        else
            dout[0] = data_in;
    end
endmodule
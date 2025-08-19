module error_detect_demux (
    input wire data,                     // Input data
    input wire [2:0] address,            // Address selection
    output reg [4:0] outputs,            // Output lines
    output reg error_flag                // Error indication
);
    always @(*) begin
        outputs = 5'b0;
        error_flag = 1'b0;
        
        if (address < 5) 
            outputs[address] = data;     // Valid routing
        else
            error_flag = data;           // Error indication for invalid addresses
    end
endmodule
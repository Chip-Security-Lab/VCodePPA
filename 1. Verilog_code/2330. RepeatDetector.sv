module RepeatDetector #(WIN=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
reg [7:0] history [0:WIN-1];
reg [3:0] ptr;
integer i;

initial begin
    ptr = 0;
    for(i=0; i<WIN; i=i+1)
        history[i] = 0;
end

always @(posedge clk) begin
    if(!rst_n) begin
        for(i=0; i<WIN; i=i+1)
            history[i] <= 0;
        ptr <= 0;
        code <= 0;
    end
    else begin
        history[ptr] <= data;
        
        if(ptr > 0 && data == history[ptr-1])
            code <= {8'hFF, data};
        else if(ptr == 0 && data == history[WIN-1])
            code <= {8'hFF, data};
        else
            code <= {8'h00, data};
            
        ptr <= (ptr == WIN-1) ? 0 : ptr + 1;
    end
end
endmodule
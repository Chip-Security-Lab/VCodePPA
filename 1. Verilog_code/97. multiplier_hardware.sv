module multiplier_hardware (
    input [7:0] a, 
    input [7:0] b,
    output reg [15:0] product
);
    always @(a or b) begin
        product = 0;
        if(a[0]) product = product + (b);
        if(a[1]) product = product + (b << 1);
        if(a[2]) product = product + (b << 2);
        if(a[3]) product = product + (b << 3);
        if(a[4]) product = product + (b << 4);
        if(a[5]) product = product + (b << 5);
        if(a[6]) product = product + (b << 6);
        if(a[7]) product = product + (b << 7);
    end
endmodule

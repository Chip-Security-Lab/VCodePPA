module rect_to_polar #(parameter WIDTH=16, ITERATIONS=8)(
    input wire signed [WIDTH-1:0] x_in,
    input wire signed [WIDTH-1:0] y_in,
    output reg [WIDTH-1:0] magnitude,
    output reg [WIDTH-1:0] angle
);
    reg signed [WIDTH-1:0] x, y;
    reg signed [WIDTH-1:0] x_temp, y_temp;
    reg [WIDTH-1:0] z;
    reg signed [WIDTH-1:0] atan_table [0:ITERATIONS-1];
    
    integer i;
    initial begin
        // CORDIC角度查找表 (scaled values)
        atan_table[0] = 32'd2949120;   // atan(2^-0) * 2^16
        atan_table[1] = 32'd1740992;   // atan(2^-1) * 2^16
        atan_table[2] = 32'd919872;    // atan(2^-2) * 2^16
        atan_table[3] = 32'd466944;    // atan(2^-3) * 2^16
        atan_table[4] = 32'd234368;    // atan(2^-4) * 2^16
        atan_table[5] = 32'd117312;    // atan(2^-5) * 2^16
        atan_table[6] = 32'd58688;     // atan(2^-6) * 2^16
        atan_table[7] = 32'd29312;     // atan(2^-7) * 2^16
    end
    
    always @* begin
        x = x_in;
        y = y_in;
        z = 0;
        
        for (i = 0; i < ITERATIONS; i = i + 1) begin
            x_temp = x;
            y_temp = y;
            
            if (y >= 0) begin
                x = x + (y >>> i);
                y = y - (x_temp >>> i);
                z = z + atan_table[i];
            end else begin
                x = x - (y >>> i);
                y = y + (x_temp >>> i);
                z = z - atan_table[i];
            end
        end
        
        // 近似计算幅度
        magnitude = x;
        angle = z;
    end
endmodule
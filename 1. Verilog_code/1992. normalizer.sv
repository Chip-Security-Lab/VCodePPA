module normalizer #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] normalized_data,
    output reg [$clog2(WIDTH)-1:0] shift_count
);
    integer i;
    reg found;
    
    always @* begin
        found = 0;
        shift_count = 0;
        
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (!found && in_data[i]) begin
                found = 1;
                shift_count = WIDTH-1 - i;
            end
        end
        
        normalized_data = in_data << shift_count;
    end
endmodule
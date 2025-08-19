module EdgeIVMU (
    input clk, rst,
    input [7:0] int_in,
    output reg [31:0] vector,
    output reg valid
);
    reg [7:0] int_prev;
    reg [31:0] vector_rom [0:7];
    wire [7:0] edge_detect;
    integer i;
    
    initial for (i = 0; i < 8; i = i + 1)
        vector_rom[i] = 32'h5000_0000 + (i * 16);
    
    assign edge_detect = int_in & ~int_prev;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            int_prev <= 8'h0;
            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            int_prev <= int_in;
            valid <= |edge_detect;
            for (i = 7; i >= 0; i = i - 1)
                if (edge_detect[i]) vector <= vector_rom[i];
        end
    end
endmodule
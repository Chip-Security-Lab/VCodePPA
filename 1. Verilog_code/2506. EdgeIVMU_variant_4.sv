//SystemVerilog
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

    // ROM initialization
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_rom[i] = 32'h5000_0000 + (i * 16);
        end
    end

    // Combinatorial edge detection
    assign edge_detect = int_in & ~int_prev;

    // Combinatorial logic to determine if any edge was detected
    wire valid_comb;
    assign valid_comb = |edge_detect;

    // Combinatorial logic: Priority encoder to find the index of the first set bit
    // Priority is given to the lowest index (0 to 7).
    wire [2:0] detected_idx_comb;
    assign detected_idx_comb =
        edge_detect[0] ? 3'd0 :
        edge_detect[1] ? 3'd1 :
        edge_detect[2] ? 3'd2 :
        edge_detect[3] ? 3'd3 :
        edge_detect[4] ? 3'd4 :
        edge_detect[5] ? 3'd5 :
        edge_detect[6] ? 3'd6 :
        edge_detect[7] ? 3'd7 :
        3'd0; // Default when no bits are set (this case is ignored by the valid check)


    // Sequential logic (registers)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            int_prev <= 8'h0;
            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            // Register the previous input value
            int_prev <= int_in;

            // Register the valid flag based on the combinatorial edge detection result
            valid <= valid_comb;

            // Update the registered vector only if a valid edge was detected
            // The vector value is selected from ROM based on the detected index
            if (valid_comb) begin
                vector <= vector_rom[detected_idx_comb];
            end
            // Implicit else: vector <= vector; (retains its previous value if valid_comb is 0)
        end
    end

endmodule
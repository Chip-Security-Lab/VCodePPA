//SystemVerilog
module booth_multiplier (
    input clk, arst,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product
);
    reg [7:0] A, Q;
    reg [8:0] M, Q_1;
    reg [3:0] count;

    // Initialize signals
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            A <= 8'b0;
            Q <= 8'b0;
            Q_1 <= 1'b0;
            product <= 16'b0;
            count <= 4'b0;
        end else begin
            if (count == 0) begin
                A <= 8'b0;
                Q <= multiplier;
                M <= {1'b0, multiplicand}; // Extend multiplicand for Booth's algorithm
                Q_1 <= 1'b0;
                count <= 4'b1000; // Set count for 8 bits
            end else begin
                case ({Q[0], Q_1})
                    2'b01: A <= A + M[7:0]; // A = A + M
                    2'b10: A <= A - M[7:0]; // A = A - M
                endcase

                // Arithmetic right shift
                {A, Q, Q_1} <= {A[7], A, Q, Q_1} >> 1;

                // Update count
                count <= count - 1;
            end
            
            // Store product after the last shift
            if (count == 1) begin
                product <= {A, Q}; // Combine A and Q for final product
            end
        end
    end
endmodule

module parity_check_async_rst (
    input clk, arst,
    input [3:0] addr,
    input [7:0] data,
    output reg parity
);
    reg data_parity;
    
    // Pre-compute parity in combinational logic
    always @(*) begin
        data_parity = ^data;
    end
    
    // Register stage with async reset
    always @(posedge clk or posedge arst) begin
        if (arst) 
            parity <= 1'b0;
        else 
            parity <= ~data_parity;
    end
endmodule
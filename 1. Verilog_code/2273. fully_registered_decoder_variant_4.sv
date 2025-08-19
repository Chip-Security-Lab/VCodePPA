//SystemVerilog
module fully_registered_decoder (
    input  wire        clk,           // System clock
    input  wire        rst,           // Active high reset
    input  wire [2:0]  addr_in,       // Input address
    output reg  [7:0]  decode_out     // Decoded output
);

    // Pipeline stage registers
    // Stage 1: Input registration
    reg [2:0] addr_pipe1;
    
    // Stage 2: Decode computation
    reg [2:0] addr_pipe2;
    reg [7:0] decode_pipe;
    
    // Data flow pipeline structure
    // ===========================
    
    // Stage 1: Input registration and synchronization
    always @(posedge clk) begin
        if (rst) begin
            addr_pipe1 <= 3'b000;
        end else begin
            addr_pipe1 <= addr_in;
        end
    end
    
    // Stage 2: Address decoding - Computation stage
    always @(posedge clk) begin
        if (rst) begin
            addr_pipe2  <= 3'b000;
            decode_pipe <= 8'b00000000;
        end else begin
            addr_pipe2  <= addr_pipe1;
            // One-hot encoding based on address
            decode_pipe <= (8'b00000001 << addr_pipe1);
        end
    end
    
    // Stage 3: Output registration and buffering
    always @(posedge clk) begin
        if (rst) begin
            decode_out <= 8'b00000000;
        end else begin
            decode_out <= decode_pipe;
        end
    end

endmodule
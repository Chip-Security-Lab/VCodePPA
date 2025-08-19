//SystemVerilog
module therm_decoder_pipelined (
    input wire clock,
    input wire reset_n,
    input wire [2:0] binary_in,
    input wire valid_in,
    output reg [7:0] therm_out,
    output reg valid_out
);

    // Pipeline stage signals
    reg [2:0] binary_pipe1;
    reg [7:0] therm_pipe1;
    reg valid_pipe1;
    
    reg [7:0] therm_pipe2;
    reg valid_pipe2;

    // Stage 1: Input register and thermometer conversion
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            binary_pipe1 <= 3'b0;
            therm_pipe1 <= 8'b0;
            valid_pipe1 <= 1'b0;
        end else begin
            binary_pipe1 <= binary_in;
            valid_pipe1 <= valid_in;
            
            // Optimized thermometer code generation
            case (binary_in)
                3'b000: therm_pipe1 <= 8'b00000000;
                3'b001: therm_pipe1 <= 8'b00000001;
                3'b010: therm_pipe1 <= 8'b00000011;
                3'b011: therm_pipe1 <= 8'b00000111;
                3'b100: therm_pipe1 <= 8'b00001111;
                3'b101: therm_pipe1 <= 8'b00011111;
                3'b110: therm_pipe1 <= 8'b00111111;
                3'b111: therm_pipe1 <= 8'b01111111;
            endcase
        end
    end

    // Stage 2: Pipeline register
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            therm_pipe2 <= 8'b0;
            valid_pipe2 <= 1'b0;
        end else begin
            therm_pipe2 <= therm_pipe1;
            valid_pipe2 <= valid_pipe1;
        end
    end

    // Stage 3: Output register
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            therm_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            therm_out <= therm_pipe2;
            valid_out <= valid_pipe2;
        end
    end

endmodule
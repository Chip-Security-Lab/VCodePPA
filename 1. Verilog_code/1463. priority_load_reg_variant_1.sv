//SystemVerilog
module priority_load_reg (
    input wire clk,
    input wire rst_n,
    
    // Data channel A with valid-ready handshake
    input wire [7:0] data_a,
    input wire valid_a,
    output reg ready_a,
    
    // Data channel B with valid-ready handshake
    input wire [7:0] data_b,
    input wire valid_b, 
    output reg ready_b,
    
    // Data channel C with valid-ready handshake
    input wire [7:0] data_c,
    input wire valid_c,
    output reg ready_c,
    
    // Output with valid signal
    output reg [7:0] result,
    output reg result_valid
);

    // Pipeline stages for data flow
    reg [7:0] data_selected;
    reg [1:0] select;
    reg data_valid;
    
    // Handshake control signals
    reg processing;
    
    // Priority encoder with valid-ready handshake
    always @(*) begin
        // Default values
        ready_a = 1'b0;
        ready_b = 1'b0;
        ready_c = 1'b0;
        
        if (!processing) begin
            if (valid_a) begin
                ready_a = 1'b1;
            end else if (valid_b) begin
                ready_b = 1'b1;
            end else if (valid_c) begin
                ready_c = 1'b1;
            end
        end
    end
    
    // Input stage with handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_selected <= 8'h00;
            select <= 2'b00;
            data_valid <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (!processing) begin
                if (valid_a && ready_a) begin
                    data_selected <= data_a;
                    select <= 2'b01;
                    data_valid <= 1'b1;
                    processing <= 1'b1;
                end else if (valid_b && ready_b) begin
                    data_selected <= data_b;
                    select <= 2'b10;
                    data_valid <= 1'b1;
                    processing <= 1'b1;
                end else if (valid_c && ready_c) begin
                    data_selected <= data_c;
                    select <= 2'b11;
                    data_valid <= 1'b1;
                    processing <= 1'b1;
                end else begin
                    data_valid <= 1'b0;
                end
            end else if (result_valid) begin
                // Reset processing when result has been taken
                processing <= 1'b0;
                data_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'h00;
            result_valid <= 1'b0;
        end else begin
            result_valid <= data_valid;
            if (data_valid) begin
                result <= data_selected;
            end
        end
    end

endmodule
module subtractor_8bit_valid_ready (
    input wire clk,
    input wire rst_n,
    
    // Input interface with valid-ready handshake
    input wire [7:0] a,
    input wire [7:0] b,
    input wire in_valid,
    output reg in_ready,
    
    // Output interface with valid-ready handshake
    output reg [7:0] diff,
    output reg out_valid,
    input wire out_ready
);

    // Pipeline registers
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [7:0] diff_reg;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam OUTPUT = 2'b10;
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (in_valid) begin
                    next_state = COMPUTE;
                end else begin
                    next_state = IDLE;
                end
            end
            
            COMPUTE: begin
                next_state = OUTPUT;
            end
            
            OUTPUT: begin
                if (out_ready) begin
                    next_state = IDLE;
                end else begin
                    next_state = OUTPUT;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            in_ready <= 1'b0;
        end else begin
            if (current_state == IDLE && in_valid) begin
                a_reg <= a;
                b_reg <= b;
                in_ready <= 1'b0;
            end else if (current_state == OUTPUT && out_ready) begin
                in_ready <= 1'b1;
            end else if (current_state == IDLE) begin
                in_ready <= 1'b1;
            end
        end
    end
    
    // Computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_reg <= 8'b0;
        end else if (current_state == COMPUTE) begin
            diff_reg <= a_reg - b_reg;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 8'b0;
            out_valid <= 1'b0;
        end else begin
            if (current_state == OUTPUT) begin
                diff <= diff_reg;
                out_valid <= 1'b1;
            end else if (current_state == IDLE || current_state == COMPUTE) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
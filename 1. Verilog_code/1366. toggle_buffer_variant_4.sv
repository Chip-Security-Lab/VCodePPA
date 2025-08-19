//SystemVerilog
module toggle_buffer (
    input wire clk,
    input wire toggle,
    input wire [15:0] data_in,
    input wire write_en,
    output wire [15:0] data_out
);
    reg [15:0] buffer_a, buffer_b;
    reg sel;
    
    // Selection logic for toggling
    always @(posedge clk) begin
        if (toggle) begin
            sel <= ~sel;
        end
    end
    
    // Booth multiplier signals
    reg [15:0] multiplier, multiplicand;
    wire [15:0] product;
    
    // Instantiate Booth multiplier
    booth_multiplier booth_mult (
        .clk(clk),
        .reset(1'b0),
        .multiplier(multiplier),
        .multiplicand(multiplicand),
        .product(product)
    );
    
    // Write logic with Booth multiplication
    always @(posedge clk) begin
        if (write_en) begin
            // Set multiplicand to a constant value and multiplier to input data
            multiplicand <= 16'h0001; // Using 1 as multiplicand for identity operation
            multiplier <= data_in;
            
            case (sel)
                1'b1: buffer_a <= product;
                1'b0: buffer_b <= product;
            endcase
        end
    end
    
    // Output mux with explicit structure
    reg [15:0] data_out_reg;
    always @(*) begin
        case (sel)
            1'b1: data_out_reg = buffer_b;
            1'b0: data_out_reg = buffer_a;
        endcase
    end
    assign data_out = data_out_reg;
endmodule

// Booth Multiplier Module (16-bit)
module booth_multiplier (
    input wire clk,
    input wire reset,
    input wire [15:0] multiplier,
    input wire [15:0] multiplicand,
    output reg [15:0] product
);
    // Internal registers
    reg [15:0] m_reg;        // Multiplicand register
    reg [15:0] a_reg;        // Accumulator
    reg [15:0] q_reg;        // Multiplier register
    reg q_n1;                // Extra bit for Booth algorithm
    reg [4:0] count;         // Counter for 16 iterations
    
    // State definitions
    localparam IDLE = 2'b00,
               CALC = 2'b01,
               DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // State machine sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // State machine combinational logic
    always @(*) begin
        case (state)
            IDLE: next_state = CALC;
            CALC: next_state = (count == 16) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Booth algorithm implementation
    always @(posedge clk) begin
        if (reset) begin
            a_reg <= 16'b0;
            q_reg <= 16'b0;
            q_n1 <= 1'b0;
            m_reg <= 16'b0;
            count <= 5'b0;
            product <= 16'b0;
        end else begin
            case (state)
                IDLE: begin
                    a_reg <= 16'b0;
                    q_reg <= multiplier;
                    q_n1 <= 1'b0;
                    m_reg <= multiplicand;
                    count <= 5'b0;
                end
                
                CALC: begin
                    // Check Booth encoding (2 bits at a time)
                    case ({q_reg[0], q_n1})
                        2'b01: a_reg <= a_reg + m_reg;    // Add multiplicand
                        2'b10: a_reg <= a_reg - m_reg;    // Subtract multiplicand
                        default: a_reg <= a_reg;          // No operation (00 or 11)
                    endcase
                    
                    // Arithmetic right shift of {A, Q, q_n1}
                    q_n1 <= q_reg[0];
                    q_reg <= {a_reg[0], q_reg[15:1]};
                    a_reg <= {a_reg[15], a_reg[15:1]};    // Sign extension
                    
                    count <= count + 1;
                end
                
                DONE: begin
                    product <= q_reg;  // Final product output
                end
            endcase
        end
    end
endmodule
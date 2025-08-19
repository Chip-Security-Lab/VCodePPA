//SystemVerilog
module fsm_display_codec (
    input wire clk,
    input wire rst_n,
    input wire [23:0] pixel_in,
    input wire start_conversion,
    output reg [15:0] pixel_out,
    output reg busy,
    output reg done
);
    // FSM state definitions
    localparam [1:0] IDLE = 2'b00,
                     PRE_PROCESS = 2'b01,
                     PROCESS = 2'b10,
                     OUTPUT = 2'b11;
    
    // Internal registers
    reg [1:0] state, next_state;
    
    // Control signals and intermediate data registers
    reg data_ready;
    reg process_valid;
    reg [23:0] pixel_staged;
    
    // Pre-computed RGB565 conversion registers - moved forward
    reg [4:0] r_bits;
    reg [5:0] g_bits;
    reg [4:0] b_bits;
    reg [15:0] rgb565_data;
    
    // State machine - sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic - combinational path
    always @(*) begin
        case (state)
            IDLE:       next_state = start_conversion ? PRE_PROCESS : IDLE;
            PRE_PROCESS: next_state = PROCESS;
            PROCESS:    next_state = OUTPUT;
            OUTPUT:     next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end
    
    // Pre-compute the RGB components immediately from input - forward retiming
    always @(*) begin
        r_bits = pixel_in[23:19]; // 5 bits R
        g_bits = pixel_in[15:10]; // 6 bits G
        b_bits = pixel_in[7:3];   // 5 bits B
    end
    
    // Pipeline stage 1: Input handling and pre-processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_staged <= 24'h0;
            busy <= 1'b0;
            process_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= start_conversion;
                    process_valid <= 1'b0;
                    if (start_conversion) begin
                        // Store the pre-computed RGB565 components
                        pixel_staged <= pixel_in;
                    end
                end
                PRE_PROCESS: begin
                    busy <= 1'b1;
                    process_valid <= 1'b1;
                end
                PROCESS: begin
                    busy <= 1'b1;
                    process_valid <= 1'b0;
                end
                OUTPUT: begin
                    busy <= 1'b0;
                    process_valid <= 1'b0;
                end
            endcase
        end
    end
    
    // Pipeline stage 2: RGB conversion with forwarded registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb565_data <= 16'h0;
            data_ready <= 1'b0;
        end else begin
            data_ready <= (state == PROCESS);
            
            if (process_valid) begin
                // Assemble the RGB565 data from previously computed components
                rgb565_data <= {pixel_staged[23:19], pixel_staged[15:10], pixel_staged[7:3]};
            end
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 16'h0;
            done <= 1'b0;
        end else begin
            done <= (state == OUTPUT);
            
            if (data_ready)
                pixel_out <= rgb565_data;
        end
    end
endmodule
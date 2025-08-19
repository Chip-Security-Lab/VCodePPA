//SystemVerilog
module multi_channel_range_detector(
    input wire clk,
    input wire rst_n,
    
    // Control and status signals
    input wire [31:0] data_in,
    input wire [3:0] data_valid,
    input wire config_valid,
    input wire [1:0] config_type,
    input wire [7:0] config_value,
    output wire [1:0] status,
    output wire [31:0] read_data,
    output wire read_valid,
    input wire read_request,
    input wire [2:0] read_address,
    
    // Handshake signals
    output wire busy,
    output wire done,
    input wire start
);

    reg [7:0] data_ch1, data_ch2;
    reg [7:0] lower_bound, upper_bound;
    reg ch1_in_range, ch2_in_range;
    
    localparam ADDR_DATA_CH1     = 3'h0;
    localparam ADDR_DATA_CH2     = 3'h1;
    localparam ADDR_LOWER_BOUND  = 3'h2;
    localparam ADDR_UPPER_BOUND  = 3'h3;
    localparam ADDR_STATUS       = 3'h4;
    
    wire ch1_result, ch2_result;
    
    comparator comp1(.data(data_ch1), .low(lower_bound), .high(upper_bound), .result(ch1_result));
    comparator comp2(.data(data_ch2), .low(lower_bound), .high(upper_bound), .result(ch2_result));
    
    // State definitions
    reg [1:0] main_state;
    localparam STATE_IDLE = 2'b00;
    localparam STATE_PROCESSING = 2'b01;
    localparam STATE_READ = 2'b10;
    localparam STATE_DONE = 2'b11;
    
    // Internal registers
    reg [31:0] read_data_reg;
    reg read_valid_reg;
    reg busy_reg;
    reg done_reg;
    
    // Output assignments
    assign status = {ch2_in_range, ch1_in_range};
    assign read_data = read_data_reg;
    assign read_valid = read_valid_reg;
    assign busy = busy_reg;
    assign done = done_reg;
    
    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_state <= STATE_IDLE;
            data_ch1 <= 8'h00;
            data_ch2 <= 8'h00;
            lower_bound <= 8'h00;
            upper_bound <= 8'h00;
            read_data_reg <= 32'h0;
            read_valid_reg <= 1'b0;
            busy_reg <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            case (main_state)
                STATE_IDLE: begin
                    done_reg <= 1'b0;
                    
                    if (start) begin
                        busy_reg <= 1'b1;
                        main_state <= STATE_PROCESSING;
                    end else begin
                        busy_reg <= 1'b0;
                    end
                end
                
                STATE_PROCESSING: begin
                    if (config_valid) begin
                        case (config_type)
                            2'b00: lower_bound <= config_value;
                            2'b01: upper_bound <= config_value;
                            2'b10: data_ch1 <= config_value;
                            2'b11: data_ch2 <= config_value;
                        endcase
                    end
                    
                    if (data_valid[0]) 
                        data_ch1 <= data_in[7:0];
                    if (data_valid[1]) 
                        data_ch2 <= data_in[15:8];
                    if (data_valid[2]) 
                        lower_bound <= data_in[23:16];
                    if (data_valid[3]) 
                        upper_bound <= data_in[31:24];
                    
                    if (read_request) begin
                        main_state <= STATE_READ;
                        read_valid_reg <= 1'b0;
                    end else if (!busy_reg) begin
                        main_state <= STATE_DONE;
                    end
                end
                
                STATE_READ: begin
                    case (read_address)
                        ADDR_DATA_CH1: read_data_reg <= {24'h0, data_ch1};
                        ADDR_DATA_CH2: read_data_reg <= {24'h0, data_ch2};
                        ADDR_LOWER_BOUND: read_data_reg <= {24'h0, lower_bound};
                        ADDR_UPPER_BOUND: read_data_reg <= {24'h0, upper_bound};
                        ADDR_STATUS: read_data_reg <= {30'h0, ch2_in_range, ch1_in_range};
                        default: read_data_reg <= 32'h0;
                    endcase
                    
                    read_valid_reg <= 1'b1;
                    main_state <= STATE_PROCESSING;
                end
                
                STATE_DONE: begin
                    done_reg <= 1'b1;
                    busy_reg <= 1'b0;
                    main_state <= STATE_IDLE;
                end
                
                default: main_state <= STATE_IDLE;
            endcase
        end
    end
    
    // Status update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ch1_in_range <= 1'b0;
            ch2_in_range <= 1'b0;
        end else begin
            ch1_in_range <= ch1_result;
            ch2_in_range <= ch2_result;
        end
    end

endmodule

module comparator(
    input wire [7:0] data,
    input wire [7:0] low,
    input wire [7:0] high,
    output wire result
);
    assign result = (data >= low) && (data <= high);
endmodule
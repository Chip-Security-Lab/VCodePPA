//SystemVerilog
module usb_device_addr_reg(
    input wire clk,
    input wire rst_b,
    input wire set_address,
    input wire [6:0] new_address,
    input wire [3:0] pid,
    input wire [6:0] token_address,
    output reg address_match,
    output reg [6:0] device_address
);
    // Local parameters for PID types
    localparam PID_SETUP = 4'b1101;
    localparam PID_IN    = 4'b1001;
    localparam PID_OUT   = 4'b0001;
    
    // Device address register
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            device_address <= 7'h00;
        end else if (set_address) begin
            device_address <= new_address;
        end
    end
    
    // Optimized comparison pipeline
    reg [6:0] token_addr_reg;
    reg [3:0] pid_reg;
    reg is_setup_transaction;
    reg address_valid;
    
    // Stage 1: Register inputs and optimize comparison logic
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            token_addr_reg <= 7'h00;
            pid_reg <= 4'h0;
            is_setup_transaction <= 1'b0;
            address_valid <= 1'b0;
        end else begin
            token_addr_reg <= token_address;
            pid_reg <= pid;
            is_setup_transaction <= (pid == PID_SETUP);
            
            // Optimized address comparison using a single comparison
            // For SETUP transactions: match if address is 0 or equals device_address
            // For IN/OUT transactions: match only if address equals device_address
            address_valid <= (token_address == 7'h00) || (token_address == device_address);
        end
    end
    
    // Stage 2: Final address matching logic with reduced comparators
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            address_match <= 1'b0;
        end else begin
            // Optimized decision logic
            if (pid_reg == PID_IN || pid_reg == PID_OUT) begin
                // For IN/OUT: address must match device_address
                address_match <= (token_addr_reg == device_address);
            end else if (is_setup_transaction) begin
                // For SETUP: address can be 0 or device_address
                address_match <= address_valid;
            end else begin
                address_match <= 1'b0;
            end
        end
    end
endmodule
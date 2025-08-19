//SystemVerilog
module usb_dual_port_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    // Port A - USB Interface
    input wire clk_a,
    input wire rst_a,        // Added reset for Port A
    input wire en_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_a_in,
    output reg [DATA_WIDTH-1:0] data_a_out,
    output reg valid_a_out,  // Added valid signal for Port A
    
    // Port B - System Interface
    input wire clk_b,
    input wire rst_b,        // Added reset for Port B
    input wire en_b,
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] data_b_in,
    output reg [DATA_WIDTH-1:0] data_b_out,
    output reg valid_b_out   // Added valid signal for Port B
);
    // Memory array
    reg [DATA_WIDTH-1:0] ram [(1<<ADDR_WIDTH)-1:0];
    
    // Pipeline registers for Port A
    reg [ADDR_WIDTH-1:0] addr_a_stage1;
    reg en_a_stage1, we_a_stage1;
    reg [DATA_WIDTH-1:0] data_a_in_stage1;
    reg valid_a_stage1;
    
    // Pipeline registers for Port B
    reg [ADDR_WIDTH-1:0] addr_b_stage1;
    reg en_b_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] data_b_in_stage1;
    reg valid_b_stage1;
    
    // Port A - Stage 1: Register inputs
    always @(posedge clk_a) begin
        if (rst_a) begin
            addr_a_stage1 <= {ADDR_WIDTH{1'b0}};
            en_a_stage1 <= 1'b0;
            we_a_stage1 <= 1'b0;
            data_a_in_stage1 <= {DATA_WIDTH{1'b0}};
            valid_a_stage1 <= 1'b0;
        end else begin
            addr_a_stage1 <= addr_a;
            en_a_stage1 <= en_a;
            we_a_stage1 <= we_a;
            data_a_in_stage1 <= data_a_in;
            valid_a_stage1 <= en_a;
        end
    end
    
    // Port A - Stage 2: Memory access and output
    always @(posedge clk_a) begin
        if (rst_a) begin
            data_a_out <= {DATA_WIDTH{1'b0}};
            valid_a_out <= 1'b0;
        end else begin
            valid_a_out <= valid_a_stage1;
            
            if (valid_a_stage1 && en_a_stage1) begin
                if (we_a_stage1)
                    ram[addr_a_stage1] <= data_a_in_stage1;
                data_a_out <= ram[addr_a_stage1];
            end
        end
    end
    
    // Port B - Stage 1: Register inputs
    always @(posedge clk_b) begin
        if (rst_b) begin
            addr_b_stage1 <= {ADDR_WIDTH{1'b0}};
            en_b_stage1 <= 1'b0;
            we_b_stage1 <= 1'b0;
            data_b_in_stage1 <= {DATA_WIDTH{1'b0}};
            valid_b_stage1 <= 1'b0;
        end else begin
            addr_b_stage1 <= addr_b;
            en_b_stage1 <= en_b;
            we_b_stage1 <= we_b;
            data_b_in_stage1 <= data_b_in;
            valid_b_stage1 <= en_b;
        end
    end
    
    // Port B - Stage 2: Memory access and output
    always @(posedge clk_b) begin
        if (rst_b) begin
            data_b_out <= {DATA_WIDTH{1'b0}};
            valid_b_out <= 1'b0;
        end else begin
            valid_b_out <= valid_b_stage1;
            
            if (valid_b_stage1 && en_b_stage1) begin
                if (we_b_stage1)
                    ram[addr_b_stage1] <= data_b_in_stage1;
                data_b_out <= ram[addr_b_stage1];
            end
        end
    end
    
    // Data hazard handling - Read-after-write forwarding for Port A
    reg [DATA_WIDTH-1:0] forward_data_a;
    reg forward_valid_a;
    
    always @(posedge clk_a) begin
        if (rst_a) begin
            forward_data_a <= {DATA_WIDTH{1'b0}};
            forward_valid_a <= 1'b0;
        end else begin
            forward_valid_a <= (valid_a_stage1 && en_a_stage1 && we_a_stage1 && 
                               (addr_a == addr_a_stage1));
            if (valid_a_stage1 && en_a_stage1 && we_a_stage1)
                forward_data_a <= data_a_in_stage1;
        end
    end
    
    // Data hazard handling - Read-after-write forwarding for Port B
    reg [DATA_WIDTH-1:0] forward_data_b;
    reg forward_valid_b;
    
    always @(posedge clk_b) begin
        if (rst_b) begin
            forward_data_b <= {DATA_WIDTH{1'b0}};
            forward_valid_b <= 1'b0;
        end else begin
            forward_valid_b <= (valid_b_stage1 && en_b_stage1 && we_b_stage1 && 
                               (addr_b == addr_b_stage1));
            if (valid_b_stage1 && en_b_stage1 && we_b_stage1)
                forward_data_b <= data_b_in_stage1;
        end
    end
endmodule
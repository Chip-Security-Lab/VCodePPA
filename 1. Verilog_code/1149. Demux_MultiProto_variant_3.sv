//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: Demux_MultiProto_Top.v
///////////////////////////////////////////////////////////////////////////////

module Demux_MultiProto_Top #(
    parameter DW = 8
)(
    input                  clk,
    input                  rst_n,              // Added reset signal for pipeline control
    input                  valid_in,           // Input data valid signal
    input      [1:0]       proto_sel,          // 0:SPI, 1:I2C, 2:UART
    input      [DW-1:0]    data,
    output     [2:0][DW-1:0] proto_out,
    output                 valid_out           // Output data valid signal
);

    // Pipeline stage signals
    // Stage 1: Protocol selection
    reg        [1:0]       proto_sel_stage1;
    reg        [DW-1:0]    data_stage1;
    reg                    valid_stage1;
    
    // Stage 2: Protocol handling
    reg        [2:0]       protocol_en_stage2;  // One-hot encoded protocol enable signals
    reg        [DW-1:0]    data_stage2;
    reg                    valid_stage2;
    
    // Stage 3: Data output
    reg        [2:0][DW-1:0] proto_data_stage3;
    reg                    valid_stage3;
    
    // Stage 1: Protocol Selection Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            proto_sel_stage1 <= 2'b0;
            data_stage1      <= {DW{1'b0}};
            valid_stage1     <= 1'b0;
        end else begin
            proto_sel_stage1 <= proto_sel;
            data_stage1      <= data;
            valid_stage1     <= valid_in;
        end
    end
    
    // Stage 2: Protocol Enable Decoding and Data Forwarding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            protocol_en_stage2 <= 3'b0;
            data_stage2        <= {DW{1'b0}};
            valid_stage2       <= 1'b0;
        end else begin
            // Protocol selection decoding with one-hot encoding
            case (proto_sel_stage1)
                2'd0: protocol_en_stage2 <= 3'b001;  // SPI
                2'd1: protocol_en_stage2 <= 3'b010;  // I2C
                2'd2: protocol_en_stage2 <= 3'b100;  // UART
                default: protocol_en_stage2 <= 3'b000;
            endcase
            
            data_stage2  <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Protocol-specific Data Processing
    wire [DW-1:0] spi_data_stage3;
    wire [DW-1:0] i2c_data_stage3;
    wire [DW-1:0] uart_data_stage3;
    
    // Instantiate protocol data handler modules
    SPI_Handler #(
        .DW(DW)
    ) spi_handler_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .data         (data_stage2),
        .spi_en       (protocol_en_stage2[0]),
        .valid_in     (valid_stage2),
        .spi_data     (spi_data_stage3),
        .valid_out    ()  // Not used individually, combined below
    );
    
    I2C_Handler #(
        .DW(DW)
    ) i2c_handler_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .data         (data_stage2),
        .i2c_en       (protocol_en_stage2[1]),
        .valid_in     (valid_stage2),
        .i2c_data     (i2c_data_stage3),
        .valid_out    ()  // Not used individually, combined below
    );
    
    UART_Handler #(
        .DW(DW)
    ) uart_handler_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .data         (data_stage2),
        .uart_en      (protocol_en_stage2[2]),
        .valid_in     (valid_stage2),
        .uart_data    (uart_data_stage3),
        .valid_out    ()  // Not used individually, combined below
    );
    
    // Stage 4: Final Output Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            proto_data_stage3 <= {3*DW{1'b0}};
            valid_stage3      <= 1'b0;
        end else begin
            proto_data_stage3[0] <= spi_data_stage3;
            proto_data_stage3[1] <= i2c_data_stage3;
            proto_data_stage3[2] <= uart_data_stage3;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output assignment
    assign proto_out = proto_data_stage3;
    assign valid_out = valid_stage3;

endmodule

///////////////////////////////////////////////////////////////////////////////
// SPI Protocol Handler
///////////////////////////////////////////////////////////////////////////////

module SPI_Handler #(
    parameter DW = 8
)(
    input                clk,
    input                rst_n,
    input      [DW-1:0]  data,
    input                spi_en,
    input                valid_in,
    output reg [DW-1:0]  spi_data,
    output reg           valid_out
);

    // Pipeline registers for SPI processing
    reg [DW-1:0] spi_data_stage1;
    reg          valid_stage1;

    // Stage 1: Initial data capture and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_data_stage1 <= {DW{1'b0}};
            valid_stage1    <= 1'b0;
        end else begin
            if (spi_en && valid_in) begin
                spi_data_stage1 <= data;
                valid_stage1    <= 1'b1;
            end else begin
                spi_data_stage1 <= {DW{1'b0}};
                valid_stage1    <= 1'b0;
            end
        end
    end

    // Stage 2: Final output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_data  <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            spi_data  <= spi_data_stage1;
            valid_out <= valid_stage1;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// I2C Protocol Handler
///////////////////////////////////////////////////////////////////////////////

module I2C_Handler #(
    parameter DW = 8
)(
    input                clk,
    input                rst_n,
    input      [DW-1:0]  data,
    input                i2c_en,
    input                valid_in,
    output reg [DW-1:0]  i2c_data,
    output reg           valid_out
);

    // Pipeline registers for I2C processing
    reg [DW-1:0] i2c_data_stage1;
    reg          valid_stage1;

    // Stage 1: Initial data capture and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c_data_stage1 <= {DW{1'b0}};
            valid_stage1    <= 1'b0;
        end else begin
            if (i2c_en && valid_in) begin
                i2c_data_stage1 <= data;
                valid_stage1    <= 1'b1;
            end else begin
                i2c_data_stage1 <= {DW{1'b0}};
                valid_stage1    <= 1'b0;
            end
        end
    end

    // Stage 2: Final output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c_data  <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            i2c_data  <= i2c_data_stage1;
            valid_out <= valid_stage1;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// UART Protocol Handler
///////////////////////////////////////////////////////////////////////////////

module UART_Handler #(
    parameter DW = 8
)(
    input                clk,
    input                rst_n,
    input      [DW-1:0]  data,
    input                uart_en,
    input                valid_in,
    output reg [DW-1:0]  uart_data,
    output reg           valid_out
);

    // Pipeline registers for UART processing
    reg [DW-1:0] uart_data_stage1;
    reg          valid_stage1;

    // Stage 1: Initial data capture and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_data_stage1 <= {DW{1'b0}};
            valid_stage1     <= 1'b0;
        end else begin
            if (uart_en && valid_in) begin
                uart_data_stage1 <= data;
                valid_stage1     <= 1'b1;
            end else begin
                uart_data_stage1 <= {DW{1'b0}};
                valid_stage1     <= 1'b0;
            end
        end
    end

    // Stage 2: Final output registration 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_data <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            uart_data <= uart_data_stage1;
            valid_out <= valid_stage1;
        end
    end

endmodule
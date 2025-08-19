//SystemVerilog
module not_gate_param #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output reg ready_out,
    input wire [WIDTH-1:0] A,
    output reg valid_out,
    input wire ready_in,
    output reg [WIDTH-1:0] Y
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2;
    
    // Pipeline stage 1: Input register with valid/ready handshaking
    reg [WIDTH-1:0] A_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (ready_stage1) begin
            A_reg <= A;
            valid_stage1 <= valid_in;
        end
    end
    
    // Ready signal for stage 1
    assign ready_stage1 = !valid_stage1 || ready_stage2;
    
    // Pipeline stage 2: Inversion logic with valid/ready handshaking
    reg [WIDTH-1:0] Y_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (ready_stage2) begin
            Y_reg <= ~A_reg;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Ready signal for stage 2
    assign ready_stage2 = !valid_stage2 || ready_in;
    
    // Output assignment with valid/ready handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
            ready_out <= 1'b0;
        end else begin
            if (valid_stage2 && ready_in) begin
                Y <= Y_reg;
                valid_out <= 1'b1;
            end else if (!ready_in) begin
                valid_out <= 1'b0;
            end
            
            ready_out <= !valid_stage2 || ready_in;
        end
    end

endmodule
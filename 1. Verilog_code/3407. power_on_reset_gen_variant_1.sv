//SystemVerilog
// Top-level module
module power_on_reset_gen (
    input  wire clk,
    input  wire power_stable,
    output wire por_reset_n
);
    // Internal signals
    wire [2:0] counter_value;
    wire       counter_max_reached;
    
    // Counter submodule
    por_counter counter_inst (
        .clk             (clk),
        .power_stable    (power_stable),
        .counter_value   (counter_value),
        .counter_max     (counter_max_reached)
    );
    
    // Reset logic submodule
    por_reset_logic reset_ctrl_inst (
        .clk               (clk),
        .power_stable      (power_stable),
        .counter_max       (counter_max_reached),
        .por_reset_n       (por_reset_n)
    );
    
endmodule

// Counter submodule with flattened control structure
module por_counter (
    input  wire       clk,
    input  wire       power_stable,
    output wire [2:0] counter_value,
    output wire       counter_max
);
    reg [2:0] counter_next;
    reg [2:0] counter_reg;
    
    // Flattened conditional structure with logical AND
    always @(*) begin
        if (!power_stable) begin
            counter_next = 3'b000;
        end else if (power_stable && counter_reg < 3'b111) begin
            counter_next = counter_reg + 1'b1;
        end else if (power_stable && counter_reg >= 3'b111) begin
            counter_next = counter_reg;
        end else begin
            counter_next = counter_reg;
        end
    end
    
    // Sequential logic
    always @(posedge clk or negedge power_stable) begin
        if (!power_stable) begin
            counter_reg <= 3'b000;
        end else begin
            counter_reg <= counter_next;
        end
    end
    
    // Output assignments
    assign counter_value = counter_reg;
    assign counter_max = (counter_reg == 3'b111);
    
endmodule

// Reset control logic with flattened control structure
module por_reset_logic (
    input  wire clk,
    input  wire power_stable,
    input  wire counter_max,
    output wire por_reset_n
);
    reg  reset_value;
    reg  por_reset_reg;
    
    // Flattened conditional structure with logical AND
    always @(*) begin
        if (!power_stable) begin
            reset_value = 1'b0;
        end else if (power_stable && counter_max) begin
            reset_value = 1'b1;
        end else if (power_stable && !counter_max) begin
            reset_value = 1'b0;
        end else begin
            reset_value = 1'b0;
        end
    end
    
    // Sequential logic
    always @(posedge clk or negedge power_stable) begin
        if (!power_stable) begin
            por_reset_reg <= 1'b0;
        end else begin
            por_reset_reg <= reset_value;
        end
    end
    
    // Output assignment
    assign por_reset_n = por_reset_reg;
    
endmodule